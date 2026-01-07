import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/canvas_entity.dart';
import 'canvas_painters.dart';
import 'drawing_preview_painter.dart';
import '../providers/canvas_preview_provider.dart';

/// Widget that displays the active/featured canvas with full details
class ActiveCanvasCard extends ConsumerWidget {
  /// The canvas to display
  final CanvasEntity canvas;

  /// Callback when the canvas is tapped to open
  final VoidCallback onOpen;

  /// Optional callback when the delete button is tapped
  final VoidCallback? onDelete;

  /// Creates an active canvas card
  const ActiveCanvasCard({
    required this.canvas,
    required this.onOpen,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final drawingDataAsync = ref.watch(canvasPreviewStreamProvider(canvas.id));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                const Spacer(),
                // Delete button
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: 'Delete canvas',
                    iconSize: 20,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Canvas preview - square aspect ratio
            GestureDetector(
              onTap: onOpen,
              child: AspectRatio(
                aspectRatio: 1.0, // Square (1:1)
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                child: Stack(
                  children: [
                    // Canvas content - use image if available, fallback to live rendering
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: drawingDataAsync.when(
                        data: (drawingData) => drawingData.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: drawingData.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => CustomPaint(
                                  size: Size.infinite,
                                  painter: DrawingPreviewPainter(drawingData: drawingData),
                                ),
                                errorWidget: (context, url, error) => CustomPaint(
                                  size: Size.infinite,
                                  painter: DrawingPreviewPainter(drawingData: drawingData),
                                ),
                              )
                            : CustomPaint(
                                size: Size.infinite,
                                painter: DrawingPreviewPainter(drawingData: drawingData),
                              ),
                        loading: () => Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        error: (_, __) => CustomPaint(
                          size: Size.infinite,
                          painter: CanvasPainterFactory.createPainter(canvas.state),
                        ),
                      ),
                    ),

                    // Live indicator (if active)
                    if (canvas.isActive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Canvas details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canvas.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${canvas.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Open'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Canvas stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CanvasStatItem(
                    icon: Icons.people_outline,
                    value: '${canvas.participantCount}',
                    label: 'Participants',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  _CanvasStatItem(
                    icon: Icons.access_time,
                    value: _formatLastUpdated(canvas.lastUpdated),
                    label: 'Last updated',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats the last updated time into a human-readable string
  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return '${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}';
    }
  }
}

/// Widget that displays a recent canvas in a compact card format
class RecentCanvasCard extends ConsumerWidget {
  /// The canvas to display
  final CanvasEntity canvas;

  /// Callback when the canvas is tapped
  final VoidCallback onTap;

  /// Optional callback when the delete button is tapped
  final VoidCallback? onDelete;

  /// Creates a recent canvas card
  const RecentCanvasCard({
    required this.canvas,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final drawingDataAsync = ref.watch(canvasPreviewStreamProvider(canvas.id));

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Canvas preview thumbnail - use real drawing data or fallback
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: drawingDataAsync.when(
                    data: (drawingData) => drawingData.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: drawingData.imageUrl!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            placeholder: (context, url) => CustomPaint(
                              painter: DrawingPreviewPainter(drawingData: drawingData),
                            ),
                            errorWidget: (context, url, error) => CustomPaint(
                              painter: DrawingPreviewPainter(drawingData: drawingData),
                            ),
                          )
                        : CustomPaint(
                            painter: DrawingPreviewPainter(drawingData: drawingData),
                          ),
                    loading: () => Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    error: (_, __) => CustomPaint(
                      painter: CanvasPainterFactory.createPainter(canvas.state),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Canvas info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canvas.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canvas.id,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${canvas.participantCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatLastUpdated(canvas.lastUpdated),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button and arrow icon
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Delete canvas',
                  iconSize: 20,
                  color: theme.colorScheme.error,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats the last updated time into a human-readable string
  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastUpdated.day}/${lastUpdated.month}';
    }
  }
}

/// Private widget for displaying canvas statistics
class _CanvasStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CanvasStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
