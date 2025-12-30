import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panci/presentation/widgets/color_picker.dart';
import 'package:panci/presentation/widgets/brush_size_selector.dart';

/// Screen that displays the drawing canvas and drawing controls.
///
/// This screen provides:
/// - A canvas container where users will eventually draw (placeholder for now)
/// - Color picker for selecting drawing colors
/// - Brush size selector for selecting stroke width
/// - App bar showing the canvas ID and a "Done" button
class DrawingCanvasScreen extends StatefulWidget {
  /// Creates a drawing canvas screen.
  ///
  /// The [canvasId] parameter identifies the shared canvas being drawn on.
  const DrawingCanvasScreen({
    super.key,
    required this.canvasId,
  });

  /// The unique identifier for this shared canvas.
  final String canvasId;

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  // Current drawing color
  Color _selectedColor = Colors.black;

  // Current brush size
  double _selectedBrushSize = 4.0;

  /// Handles the color selection change.
  void _onColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  /// Handles the brush size selection change.
  void _onBrushSizeSelected(double size) {
    setState(() {
      _selectedBrushSize = size;
    });
  }

  /// Handles the "Done" button tap.
  ///
  /// Shows a confirmation dialog and navigates back if confirmed.
  Future<void> _onDonePressed() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Drawing?'),
        content: const Text(
          'Are you done with your drawing? This will save and share your canvas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      // Navigate back to the previous screen (home screen)
      Navigator.pop(context);
    }
  }

  /// Handles the share button tap.
  ///
  /// Shows a bottom sheet with sharing options including canvas ID,
  /// quick share methods, and user invitation features.
  void _onSharePressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ShareBottomSheet(canvasId: widget.canvasId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Drawing Canvas'),
            Text(
              widget.canvasId,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Share button
          IconButton(
            onPressed: _onSharePressed,
            icon: const Icon(Icons.share),
            tooltip: 'Share canvas',
          ),
          const SizedBox(width: 8),
          // Done button
          FilledButton.icon(
            onPressed: _onDonePressed,
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Drawing canvas container (placeholder)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Canvas drawing area (placeholder)
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Drawing canvas will be here',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Touch and drag to draw',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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

          // Drawing controls toolbar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),

                  // Section title: Color
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Color',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Color picker
                  ColorPicker(
                    selectedColor: _selectedColor,
                    onColorSelected: _onColorSelected,
                  ),
                  const SizedBox(height: 16),

                  // Section title: Brush Size
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.brush,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Brush Size',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Brush size selector
                  BrushSizeSelector(
                    selectedSize: _selectedBrushSize,
                    onSizeSelected: _onBrushSizeSelected,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet widget for sharing and inviting users to a canvas.
///
/// Provides multiple sharing options:
/// - Copy canvas ID
/// - Copy invite link
/// - Share via various methods
/// - Invite specific users by email/username
/// - View pending invitations
class _ShareBottomSheet extends StatefulWidget {
  const _ShareBottomSheet({required this.canvasId});

  final String canvasId;

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  final TextEditingController _inviteController = TextEditingController();

  // Dummy data for pending invitations (placeholder for backend integration)
  final List<Map<String, String>> _pendingInvites = [
    {'email': 'user1@example.com', 'status': 'Pending'},
    {'email': 'user2@example.com', 'status': 'Sent'},
  ];

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  /// Generates an invite link for the canvas.
  String get _inviteLink => 'panci://join/${widget.canvasId}';

  /// Copies the canvas ID to clipboard.
  Future<void> _copyCanvasId() async {
    await Clipboard.setData(ClipboardData(text: widget.canvasId));

    if (!mounted) return;

    _showSnackBar(
      'Canvas ID copied: ${widget.canvasId}',
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
    );
  }

  /// Copies the invite link to clipboard.
  Future<void> _copyInviteLink() async {
    await Clipboard.setData(ClipboardData(text: _inviteLink));

    if (!mounted) return;

    _showSnackBar(
      'Invite link copied!',
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
    );
  }

  /// Shows the share via dialog (placeholder for share package integration).
  void _showShareViaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.share),
        title: const Text('Share Via'),
        content: const Text(
          'This feature will allow you to share the invite link via messaging apps, email, and social media.\n\nRequires integration with a share package.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Shows the send invite dialog (placeholder for backend integration).
  void _showSendInviteDialog() {
    if (_inviteController.text.trim().isEmpty) {
      _showSnackBar(
        'Please enter an email or username',
        icon: Icons.error_outline,
        backgroundColor: Colors.orange,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.email_outlined),
        title: const Text('Coming Soon'),
        content: Text(
          'Invite will be sent to: ${_inviteController.text}\n\nThis feature requires backend integration to send email invitations.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _inviteController.clear();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows the QR code placeholder dialog.
  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.qr_code_2),
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR code generation requires additional dependencies.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows a snackbar with the given message.
  void _showSnackBar(
    String message, {
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Row(
                        children: [
                          Icon(
                            Icons.share,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Share & Invite',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 1: Canvas ID
                      _buildSectionTitle(
                        theme,
                        icon: Icons.tag,
                        title: 'Canvas ID',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share this ID with others to join:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Canvas ID display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.canvasId,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _copyCanvasId,
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy to clipboard',
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 24),

                      // Section 2: Quick Share Options
                      _buildSectionTitle(
                        theme,
                        icon: Icons.send,
                        title: 'Quick Share',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share the canvas using these quick options:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Copy Invite Link button
                      FilledButton.tonalIcon(
                        onPressed: _copyInviteLink,
                        icon: const Icon(Icons.link),
                        label: const Text('Copy Invite Link'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Share Via button
                      OutlinedButton.icon(
                        onPressed: _showShareViaDialog,
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share via...'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // QR Code button
                      OutlinedButton.icon(
                        onPressed: _showQrCodeDialog,
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Show QR Code'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 24),

                      // Section 3: Invite Specific Users
                      _buildSectionTitle(
                        theme,
                        icon: Icons.person_add,
                        title: 'Invite Users',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Send a direct invitation by email or username:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email/Username input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inviteController,
                              decoration: InputDecoration(
                                labelText: 'Email or Username',
                                hintText: 'user@example.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _showSendInviteDialog(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _showSendInviteDialog,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                            ),
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pending invitations
                      if (_pendingInvites.isNotEmpty) ...[
                        Text(
                          'Pending Invitations',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendingInvites.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            itemBuilder: (context, index) {
                              final invite = _pendingInvites[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(invite['email']!),
                                subtitle: Text(invite['status']!),
                                trailing: Icon(
                                  Icons.schedule,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Note: This is placeholder data. Backend integration required.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Close button
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a section title widget with an icon and text.
  Widget _buildSectionTitle(
    ThemeData theme, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
