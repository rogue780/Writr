import 'package:flutter/material.dart';
import '../models/app_theme.dart';

/// A card widget that displays a theme preview with selection state
class ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const ThemeCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: _showContextMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? cardTheme.colorScheme.primary
                : cardTheme.dividerColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cardTheme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 9 : 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color preview strip
              _buildColorPreview(),
              // Theme info section
              _buildInfoSection(cardTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview() {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary color
          Expanded(
            child: Container(
              color: theme.colors.primary,
              child: Center(
                child: Text(
                  'Aa',
                  style: TextStyle(
                    color: theme.colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Secondary color
          Expanded(
            child: Container(
              color: theme.colors.secondary,
              child: Center(
                child: Text(
                  'Bb',
                  style: TextStyle(
                    color: theme.colors.onSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Surface color
          Expanded(
            child: Container(
              color: theme.colors.surface,
              child: Center(
                child: Text(
                  'Cc',
                  style: TextStyle(
                    color: theme.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData cardTheme) {
    return Container(
      color: cardTheme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  theme.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: cardTheme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (theme.isCustom) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 10,
                      color: cardTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (theme.isCustom && onEdit != null) ...[
            _buildIconButton(
              icon: Icons.edit_outlined,
              onPressed: onEdit!,
              tooltip: 'Edit theme',
              cardTheme: cardTheme,
            ),
          ],
          if (isSelected)
            Icon(
              Icons.check_circle,
              size: 18,
              color: cardTheme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ThemeData cardTheme,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        tooltip: tooltip,
        color: cardTheme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  VoidCallback? _showContextMenu(BuildContext context) {
    if (!theme.isCustom && onDuplicate == null) return null;

    return () {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero);
      final Size size = box.size;

      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + size.height,
          position.dx + size.width,
          position.dy + size.height + 100,
        ),
        items: [
          if (onDuplicate != null)
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Duplicate as Custom'),
                ],
              ),
            ),
          if (theme.isCustom && onEdit != null)
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
          if (theme.isCustom && onDelete != null)
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
        ],
      ).then((value) {
        if (!context.mounted) return;
        switch (value) {
          case 'duplicate':
            onDuplicate?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      });
    };
  }
}

/// A compact version of ThemeCard for use in smaller spaces
class ThemeCardCompact extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeCardCompact({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: theme.name,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? cardTheme.colorScheme.primary
                  : cardTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          cardTheme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSelected ? 6 : 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(color: theme.colors.primary),
                ),
                Expanded(
                  child: Container(color: theme.colors.surface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
