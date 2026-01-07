import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:panci/presentation/widgets/canvas_cards.dart';
import 'package:panci/presentation/providers/canvas_list_provider.dart';
import 'package:panci/presentation/providers/auth_provider.dart';
import 'package:panci/presentation/providers/user_provider.dart';
import 'package:panci/presentation/widgets/registration_prompt_dialog.dart';

// Note: debugPrint is already available from flutter/material.dart

/// Home screen for managing canvas sessions.
///
/// This screen displays:
/// - User profile information and authentication status
/// - The most recent/active canvas in a prominent featured card
/// - A list of recent canvases below
/// - Navigation button to join or create a new canvas
/// - Canvas creation limits for guest users
///
/// The screen follows clean architecture principles:
/// - Uses domain entities for business logic
/// - Displays data through presentation widgets
/// - Fetches real canvas data from Firebase via providers
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get real canvas data from Firebase via providers
    final mostRecentCanvas = ref.watch(mostRecentCanvasProvider);
    final recentCanvases = ref.watch(recentCanvasesProvider);

    // Get auth and user state
    final user = ref.watch(userProvider);
    final canCreateCanvas = ref.watch(canCreateCanvasProvider);

    // Determine display name
    final displayName = user?.username ?? 'Guest';
    final isGuest = user?.isGuest ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isGuest ? 'Welcome, Guest' : 'Welcome, $displayName'),
        centerTitle: true,
        actions: [
          // User menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'register') {
                Navigator.pushNamed(context, '/register');
              } else if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              } else if (value == 'login') {
                Navigator.pushNamed(context, '/login');
              }
            },
            itemBuilder: (context) => [
              // User info header
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isGuest && user?.email.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Guest User',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),

              // Register option (for guests)
              if (isGuest)
                const PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 12),
                      Text('Register Now'),
                    ],
                  ),
                ),

              // Login option (for guests who already have account)
              if (isGuest)
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login),
                      SizedBox(width: 12),
                      Text('Login'),
                    ],
                  ),
                ),

              // Logout option (for registered users)
              if (!isGuest)
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Logout'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Guest mode indicator chip
                if (isGuest) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest Mode - Register to unlock unlimited canvases',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Canvas limit indicator for guests
                if (isGuest) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest limit: ${user?.canvasCount ?? 0}/1 canvas created',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Welcome section
                Text(
                  'Welcome!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create or join a shared canvas to start drawing together.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Active/Featured canvas section
                if (mostRecentCanvas != null)
                  ActiveCanvasCard(
                    canvas: mostRecentCanvas,
                    onOpen: () => _openCanvas(context, mostRecentCanvas.id),
                    onDelete: () => _deleteCanvas(mostRecentCanvas.id),
                  )
                else
                  _buildNoActiveCanvasCard(theme),

                const SizedBox(height: 32),

                // Recent canvases section
                if (recentCanvases.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Canvases',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // List of recent canvases
                  ...recentCanvases.map(
                    (canvas) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: RecentCanvasCard(
                        canvas: canvas,
                        onTap: () => _openCanvas(context, canvas.id),
                        onDelete: () => _deleteCanvas(canvas.id),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Navigation button
                Tooltip(
                  message: canCreateCanvas
                      ? ''
                      : 'Register to create unlimited canvases',
                  child: FilledButton.icon(
                    onPressed: canCreateCanvas
                        ? () => _joinOrCreateCanvas(context)
                        : () => _showCanvasLimitDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Join or Create Canvas'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: canCreateCanvas
                          ? null
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: canCreateCanvas
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tip section
                _buildTipCard(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the card shown when there's no active canvas
  Widget _buildNoActiveCanvasCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Canvas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Empty state preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No active canvas',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Canvas preview will appear here',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Join or create a canvas to see it here',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the tip card with helpful information
  Widget _buildTipCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tip: You can share the canvas ID with friends to draw together',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a canvas with the given ID
  void _openCanvas(BuildContext context, String canvasId) {
    Navigator.pushNamed(
      context,
      '/drawing',
      arguments: canvasId,
    );
  }

  /// Navigates to the join/create canvas screen
  void _joinOrCreateCanvas(BuildContext context) {
    Navigator.pushNamed(context, '/join');
  }

  /// Shows the canvas limit dialog for guests who reached their limit
  void _showCanvasLimitDialog(BuildContext context) {
    showRegistrationPrompt(
      context,
      title: 'Canvas Limit Reached',
      message:
          "You've reached your canvas limit. Register to create unlimited canvases and unlock all features.",
    );
  }

  /// Deletes a canvas with confirmation
  Future<void> _deleteCanvas(String canvasId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Canvas?'),
        content: const Text(
          'This action cannot be undone. All strokes will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete canvas document from Firestore
      await FirebaseFirestore.instance
          .collection('canvases')
          .doc(canvasId)
          .delete();

      debugPrint('Canvas document deleted: $canvasId');

      // Delete canvas image from Storage (if exists)
      try {
        await FirebaseStorage.instance
            .ref()
            .child('canvases/$canvasId/latest.png')
            .delete();
        debugPrint('Canvas image deleted: $canvasId');
      } catch (e) {
        // Image might not exist, that's ok
        debugPrint('No image to delete or error: $e');
      }

      // Decrement canvas count
      await ref.read(userProvider.notifier).decrementCanvasCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Canvas deleted'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting canvas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to delete canvas: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
