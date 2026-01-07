import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:panci/presentation/providers/auth_provider.dart';

/// Team management screen for managing canvas collaborators.
///
/// This screen provides:
/// - Display of canvas owner
/// - List of all team members
/// - Ability to add team members by user ID
/// - Ability to remove team members (with confirmation)
/// - Visual distinction between owner and members
///
/// Only the canvas owner can access this screen.
class TeamManagementScreen extends ConsumerStatefulWidget {
  /// Creates a team management screen.
  const TeamManagementScreen({
    super.key,
    required this.canvasId,
    required this.canvasName,
  });

  /// The ID of the canvas being managed.
  final String canvasId;

  /// The name of the canvas (displayed in app bar).
  final String canvasName;

  @override
  ConsumerState<TeamManagementScreen> createState() =>
      _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  final _inviteController = TextEditingController();
  bool _isInviting = false;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  /// Shows the invite member dialog.
  Future<void> _showInviteDialog() async {
    _inviteController.clear();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _InviteMemberDialog(
        controller: _inviteController,
      ),
    );

    if (result != null && mounted) {
      await _inviteMember(result);
    }
  }

  /// Invites a member to the canvas team.
  Future<void> _inviteMember(String userId) async {
    if (userId.trim().isEmpty) {
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      // First, check if user exists in users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          _showErrorSnackBar('User not found. Please check the User ID.');
        }
        return;
      }

      // Get user data
      final userData = userDoc.data()!;
      final username = userData['username'] as String? ?? 'Unknown';

      // Add user to team members
      await FirebaseFirestore.instance
          .collection('canvases')
          .doc(widget.canvasId)
          .update({
        'teamMembers': FieldValue.arrayUnion([userId]),
      });

      if (mounted) {
        _showSuccessSnackBar('Added $username to team');
      }
    } catch (e) {
      debugPrint('Error inviting member: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to add team member: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  /// Removes a member from the canvas team.
  Future<void> _removeMember(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team Member?'),
        content: Text(
          'Are you sure you want to remove $username from the team? They will lose access to this canvas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      // Remove user from team members
      await FirebaseFirestore.instance
          .collection('canvases')
          .doc(widget.canvasId)
          .update({
        'teamMembers': FieldValue.arrayRemove([userId]),
      });

      if (mounted) {
        _showSuccessSnackBar('Removed $username from team');
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to remove team member: ${e.toString()}');
      }
    }
  }

  /// Shows a success snackbar.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error snackbar.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.canvasName),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('canvases')
            .doc(widget.canvasId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading team',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final canvasData = snapshot.data!.data() as Map<String, dynamic>?;
          if (canvasData == null) {
            return const Center(
              child: Text('Canvas not found'),
            );
          }

          final ownerId = canvasData['ownerId'] as String;
          final teamMembers = List<String>.from(
            canvasData['teamMembers'] as List<dynamic>? ?? [],
          );

          // Check if current user is owner
          final isOwner = currentUserId == ownerId;
          if (!isOwner) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Only the canvas owner can manage the team.'),
                ],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section header
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Team Members',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${teamMembers.length + 1} total members',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Team members list
                  Expanded(
                    child: ListView(
                      children: [
                        // Owner card
                        _TeamMemberCard(
                          userId: ownerId,
                          isOwner: true,
                          onRemove: null, // Can't remove owner
                        ),
                        const SizedBox(height: 12),

                        // Team members
                        ...teamMembers.map(
                          (memberId) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TeamMemberCard(
                              userId: memberId,
                              isOwner: false,
                              onRemove: () => _getUsernameAndRemove(memberId),
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
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isInviting ? null : _showInviteDialog,
        icon: _isInviting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.person_add),
        label: const Text('Invite Member'),
      ),
    );
  }

  /// Gets the username and then removes the member.
  Future<void> _getUsernameAndRemove(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final username = userDoc.exists
          ? (userDoc.data()?['username'] as String? ?? 'Unknown User')
          : 'Unknown User';

      await _removeMember(userId, username);
    } catch (e) {
      debugPrint('Error getting username: $e');
      await _removeMember(userId, 'this user');
    }
  }
}

/// Widget that displays a team member card with their profile information.
class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.userId,
    required this.isOwner,
    this.onRemove,
  });

  final String userId;
  final bool isOwner;
  final VoidCallback? onRemove;

  /// Gets the initials from a username.
  String _getInitials(String username) {
    final parts = username.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final username = snapshot.hasData && snapshot.data!.exists
            ? ((snapshot.data!.data() as Map<String, dynamic>?)?['username'] as String? ?? 'Unknown User')
            : 'Loading...';

        final email = snapshot.hasData && snapshot.data!.exists
            ? ((snapshot.data!.data() as Map<String, dynamic>?)?['email'] as String? ?? '')
            : '';

        return Card(
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _getInitials(username),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(username)),
                if (isOwner)
                  Chip(
                    label: const Text('Owner'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            subtitle: email.isNotEmpty ? Text(email) : null,
            trailing: onRemove != null
                ? IconButton(
                    icon: const Icon(Icons.person_remove),
                    onPressed: onRemove,
                    tooltip: 'Remove from team',
                    color: theme.colorScheme.error,
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Dialog for inviting a new team member.
class _InviteMemberDialog extends StatelessWidget {
  const _InviteMemberDialog({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.person_add,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Invite Team Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter the User ID of the person you want to add to the team:',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Enter user ID',
              prefixIcon: Icon(Icons.badge),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final userId = controller.text.trim();
            if (userId.isNotEmpty) {
              Navigator.of(context).pop(userId);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
