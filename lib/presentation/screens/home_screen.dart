import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/presentation/widgets/canvas_cards.dart';
import 'package:panci/presentation/providers/canvas_list_provider.dart';

/// Home screen for managing canvas sessions.
///
/// This screen displays:
/// - The most recent/active canvas in a prominent featured card
/// - A list of recent canvases below
/// - Navigation button to join or create a new canvas
///
/// The screen follows clean architecture principles:
/// - Uses domain entities for business logic
/// - Displays data through presentation widgets
/// - Fetches real canvas data from Firebase via providers
class HomeScreen extends ConsumerWidget {
  /// Creates a home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Get real canvas data from Firebase via providers
    final mostRecentCanvas = ref.watch(mostRecentCanvasProvider);
    final recentCanvases = ref.watch(recentCanvasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Canvas'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Navigation button
                FilledButton.icon(
                  onPressed: () => _joinOrCreateCanvas(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Join or Create Canvas'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
