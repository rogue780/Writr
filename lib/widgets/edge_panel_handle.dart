import 'package:flutter/material.dart';

class EdgePanelHandle extends StatelessWidget {
  const EdgePanelHandle({
    super.key,
    required this.label,
    required this.onTap,
    required this.side,
    this.width = 28,
  });

  final String label;
  final VoidCallback onTap;
  final EdgePanelSide side;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final turns = switch (side) {
      EdgePanelSide.left => 3, // bottom-to-top (B at bottom)
      EdgePanelSide.right => 1, // top-to-bottom (I at top)
    };

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            border: Border(
              left: side == EdgePanelSide.right
                  ? BorderSide(color: theme.dividerColor)
                  : BorderSide.none,
              right: side == EdgePanelSide.left
                  ? BorderSide(color: theme.dividerColor)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: RotatedBox(
              quarterTurns: turns,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum EdgePanelSide { left, right }

