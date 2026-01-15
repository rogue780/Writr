import 'package:flutter/material.dart';

/// Available view modes for the editor area.
enum ViewMode {
  editor('Editor', Icons.edit_note, 'Edit individual documents'),
  corkboard('Corkboard', Icons.dashboard, 'View documents as index cards'),
  outliner('Outliner', Icons.table_chart, 'View documents in a table'),
  scrivenings('Scrivenings', Icons.article, 'Edit multiple documents as one');

  final String label;
  final IconData icon;
  final String tooltip;
  const ViewMode(this.label, this.icon, this.tooltip);
}
