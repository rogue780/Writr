import 'package:flutter/material.dart';
import '../../services/vcs_service.dart';

/// Compact branch picker widget for the toolbar.
class VcsBranchPicker extends StatelessWidget {
  final VcsService vcsService;
  final VoidCallback? onHistoryPressed;

  const VcsBranchPicker({
    super.key,
    required this.vcsService,
    this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vcsService,
      builder: (context, child) {
        if (!vcsService.isInitialized) {
          return const SizedBox.shrink();
        }

        final colorScheme = Theme.of(context).colorScheme;
        final currentBranch = vcsService.currentBranch;
        final branches = vcsService.branches;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branch dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: PopupMenuButton<String>(
                tooltip: 'Switch branch',
                offset: const Offset(0, 36),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentBranch?.name ?? 'main',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                itemBuilder: (context) {
                  return [
                    // Branch list
                    ...branches.map((branch) {
                      final isCurrent = branch.name == currentBranch?.name;
                      return PopupMenuItem<String>(
                        value: branch.name,
                        child: Row(
                          children: [
                            if (isCurrent)
                              Icon(Icons.check, size: 16, color: colorScheme.primary)
                            else
                              const SizedBox(width: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: TextStyle(
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (branch.description != null)
                                    Text(
                                      branch.description!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Divider
                    const PopupMenuDivider(),
                    // Create new branch
                    PopupMenuItem<String>(
                      value: '_new_branch',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('New Branch...'),
                        ],
                      ),
                    ),
                    // Manage branches
                    PopupMenuItem<String>(
                      value: '_manage',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          const Text('Manage Branches...'),
                        ],
                      ),
                    ),
                  ];
                },
                onSelected: (value) async {
                  if (value == '_new_branch') {
                    _showCreateBranchDialog(context);
                  } else if (value == '_manage') {
                    onHistoryPressed?.call();
                  } else {
                    // Switch branch
                    try {
                      await vcsService.checkoutBranch(value);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            // History button
            IconButton(
              icon: const Icon(Icons.history, size: 20),
              tooltip: 'Version History',
              onPressed: onHistoryPressed,
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateBranchDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Branch Name',
                hintText: 'e.g., alternate-ending',
                helperText: 'No spaces allowed',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this branch for?',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty && context.mounted) {
      try {
        final branchName = nameController.text.trim().replaceAll(' ', '-');
        await vcsService.createBranch(
          branchName,
          description: descController.text.isNotEmpty ? descController.text : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Branch "$branchName" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
